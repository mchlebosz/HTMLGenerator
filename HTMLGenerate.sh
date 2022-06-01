#! /usr/bin/bash


rflag=false
sorted="No"
output_name="HTML";

usage()
{
   # Display Help
   echo "Creates list of files in form of simple HTML Page in current folder"
   echo "Page will be exported to new folder named HTML"
   echo
   echo "Syntax: $1 [-h] < -p path> [-o {./HTML}]  [-s ASC|DESC] [-e '<extention1> [extention2]...'] "
   echo "options:"
   echo "h     Show help for script ."
   echo "p     Path to folder from which to create HTML."
   echo "o     Output folder name where to export HTML files. Default is 'HTML'"
   echo "s     Sort files on pages in ascending or descending order."
   echo "e     Create another distinct page for given file extentions."

   read -n 1 -r -s -p $'Press enter to continue...\n';
}


while getopts "he::p:s:o:" option; do
   case $option in
        s) sorted="$OPTARG";;
        e) additional_extentions+=("$OPTARG");;
        p) path="$OPTARG"; rflag=true;;
        o) output_name="$OPTARG";;
        h  ) usage $0; exit;;
        \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
        :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
        *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
   esac
done
#shift $((OPTIND -1))



if ! $rflag
then
    echo "-p must be included" >&2
    exit 1
fi



#check if path exists
if [ ! -d "$path" ]; then
    echo "Path $path does not exist" >&2
    exit 1
fi

#check if out name exists
if [ ! -d "./$output_name" ]; then
   mkdir -p "$output_name"
fi

output_dir=$(pwd)"/$output_name"



#translate $path to absolute path
cd $path;
absolute_path="$(pwd)";



echo "Path: $path";
echo "Absolute Path: $absolute_path";
echo "OS: $OSTYPE";
echo "Output dir: $output_dir";
echo "Sorted: $sorted";

#create array for extentions
declare -A file_extentions
file_extentions["Documents"]=".doc|.docx|.odt|.pdf|.rtf|.txt|.wpd|.wps|.xls|.xlsx|.xml|.csv|.pptx"
file_extentions["Images"]=".bmp|.gif|.jpeg|.jpg|.png|.psd|.psp|.thm|.tif|.tiff|.ico|.ai|.eps|.ps|.svg|.xcf|.raw|.cr2|.nef|.orf|.arw|.dng|.rw2|.raf|.pef|.x3f|.webp"
file_extentions["Audio"]=".aac|.aif|.aiff|.flac|.m4a|.m4b|.m4p|.m4r|.mp3|.mpc|.oga|.ogg|.opus|.ra|.wav|.wma"
file_extentions["Video"]=".3g2|.3gp|.asf|.avi|.flv|.m4v|.mkv|.mov|.mp4|.mpg|.mpeg|.rm|.swf|.vob|.wmv"
file_extentions["Additional"]="$(echo ${additional_extentions[@]}| sed -e 's/ /|./g'  | xargs -I {} echo -n ".{}" | tr -s "." )";


all_files=$(find "$absolute_path" -type f | xargs -I % echo "\"%\"");



#transform for all file_extentions from string to array
#because cannot assign list to array member
for i in "${!file_extentions[@]}"; do
    file_extentions[$i]=$(echo "${file_extentions[$i]}" | tr "|" " " | sed -e 's/\./\\\./g');
done

#echo "File Extentions: ${file_extentions[@]}"

#add only files with given extentions
declare -A files;
for i in "${!file_extentions[@]}"; do
   for extention in ${file_extentions[$i]}; do
      file_path="$(echo "$all_files" | grep ""$extention"\"$")";
      if [[ "$file_path" != "" ]]; then
         files[$i]+="$(echo $file_path) ";
      fi
   done
done

all_extentions="";

#create other by adding only what is left
files["Other"]=""

#create array with all given extentions
for i in "${file_extentions[@]}"; do
   for e in $i; do
      all_extentions+=$(echo "$e|");
   done
done

#need to create special list of .extention"$
#doesnt work otherwise
mod_ext=$(echo "$all_extentions" | sed -e 's/|/\"$|/g' | sed -e 's/|$//g');
#echo "$mod_ext";

all_extentions=$(echo "$all_extentions" | sed -e 's/|$//g'  | xargs -I {} echo -n ".{}" | tr -s "." )
#echo "$all_extentions";

files["Other"]="$(echo "$all_files" | egrep -v "$mod_ext" | xargs -I % echo "\"%\"")";


#sort file categories
if [ "$sorted" == "DESC" ]; then
   for i in "${!file_extentions[@]}"; do
      file_extentions[$i]=$(echo "${file_extentions[$i]}"  | xargs -n1 | sort -r |  xargs );
   done
   #sort files using only its name not full path
   for i in "${!files[@]}"; do
      files[$i]=$(echo "${files[$i]}" | xargs -n1 | sort -r |  xargs -I % echo "\"%\"");
   done
elif [ "$sorted" == "ASC" ]; then
   for i in "${!file_extentions[@]}"; do
         file_extentions[$i]=$(echo "${file_extentions[$i]}" | xargs -n1 | sort |  xargs);
   done
   for i in "${!files[@]}"; do
      files[$i]=$(echo "${files[$i]}" | xargs -n1 | sort |  xargs -I % echo "\"%\"");
   done
else
   for i in "${!file_extentions[@]}"; do
         file_extentions[$i]=$(echo "${file_extentions[$i]}" | xargs -n1 |  xargs);
   done
   for i in "${!files[@]}"; do
      files[$i]=$(echo "${files[$i]}" | xargs -n1 |  xargs -I % echo "\"%\"");
   done

fi

#print files
# for i in "${!files[@]}"; do
#     printf "$i:\n${files[$i]}\n";
#     echo "";
# done



custom_styling(){
   echo "
   .table-fixed {
    overflow: auto;
    height: calc(100vh - 56px);
   }
   .table-fixed thead th {
    position: sticky;
    top: 0;
    z-index: 1;
   }"
}

#Using Bootstrap
#           1           2                3
#nav_menu $pageTitle  $extentions     $files
nav_menu() {
   declare -n extentions=$2
   declare -n found_files=$3;
   echo "<nav class=\"navbar fixed-top navbar-expand-lg navbar-dark bg-dark \">
   <div class=\"container-fluid flex-d\">"
   overcat=""
   for cat in "${!extentions[@]}"; do
      if  [[ "${extentions[$cat]}" =~ "$1" ]]; then
         overcat=$(printf "$cat");
      fi
   done
   if [ "$overcat" == "" ]; then
      echo "<a class=\"navbar-brand fw-bolder\" href=\"$1.html\">$1</a>"
   else
      echo "<a class=\"navbar-brand fw-bolder\" href=\"$1.html\">$overcat ➡ $1</a>"
   fi
  echo "<button class=\"navbar-toggler\" type=\"button\"
  data-toggle=\"collapse\"
  data-bs-toggle=\"collapse\"
  data-bs-target=\"#navbarSupportedContent\"
  data-target=\"#navbarSupportedContent\"
  aria-controls=\"navbarSupportedContent\"
  aria-expanded=\"false\"
  aria-label=\"Toggle navigation\">
    <span class=\"navbar-toggler-icon\"></span>
  </button>

  <div class=\"collapse me-auto navbar-collapse text-light\" id=\"navbarSupportedContent\">
    <ul class=\"navbar-nav ms-auto mr-auto d-flex flex-column flex-lg-row justify-content-end align-items-baseline\">"
   for  i in "${!extentions[@]}"; do
      echo "<li class=\"nav-item me-2 btn-group dropdown\"><div class=\"btn-group\">"
      #echo "${found_files[$i]}";
      if [ "${found_files[$i]}" != "" ] ; then
      #if title is equal to current category or title is in current category
         if [ "$1" == "$i" ]  || [[ "${extentions[$i]}" =~ "$1" ]]; then
         echo "<a class=\"nav-link btn btn-dark btn-outline-dark active\" href=\"$i.html\"
         id=\"navbar$i\">
         $i <span class=\"visually-hidden\">(current)</span>
         </a>"
         echo "<a class=\"nav-link btn btn-dark btn-outline-dark active dropdown-toggle dropdown-toggle-split px-2\" href=\"$i.html\"
         id=\"navbar$i\"
         role=\"button\"
         data-toggle=\"$i\"
         data-bs-toggle=\"dropdown\"
         aria-haspopup=\"true\"
         aria-expanded=\"false\">
         <span class=\"visually-hidden\">Toggle Dropdown</span>
         </a>"
         else
         echo "<a class=\"nav-link btn btn-dark btn-outline-dark\" href=\"$i.html\"
         id=\"navbar$i\">

         $i
         </a>"
         echo "<a class=\"nav-link btn btn-dark btn-outline-dark dropdown-toggle dropdown-toggle-split px-2\" href=\"$i.html\"
         id=\"navbar$i\"
         role=\"button\"
         data-toggle=\"$i\"
         data-bs-toggle=\"dropdown\"
         aria-haspopup=\"true\"
         aria-expanded=\"false\">
         <span class=\"visually-hidden\">Toggle Dropdown</span>
         </a>"
         fi

         echo "<div class=\"dropdown-menu\" aria-labelledby=\"navbar$i\">"
         #if $1 is in $6 name
         for e in ${extentions[$i]}; do
            #check if extention is in files[$i]
            if [[ "${found_files[$i]}" == *"${e:1}"* ]]; then
               #if extention is
               if [[ "$1" == "${e:1}" ]]; then
                  echo "<a
                  class=\"dropdown-item active\"
                  href=\"${e:1}.html\">${e:1}<span
                  class=\"visually-hidden\">(current)</span></a>";
               else
                  echo "<a class=\"dropdown-item\" href=\"${e:1}.html\">${e:1}</a>";
               fi
            else
               echo "<a class=\"dropdown-item disabled\" href=\"${e:1}.html\">${e:1}</a>";
            fi
         done
         echo "</div>"
      else
         echo "<a class=\"nav-link btn btn-dark btn-outline-dark disabled\" href=\"${e:1}.html\">$i</a>"
      fi
   done
   echo "</div></li>
   <li class=\"nav-item btn-group\">"
   if [ "${found_files[Other]}" != "" ]; then
        if [[ "$1" == "Other" ]]; then
             echo "<a class=\"nav-link btn btn-dark btn-outline-dark active\" href=\"Other.html\">Other<span class=\"visually-hidden\">(current)</span></a>"
         else
             echo "<a class=\"nav-link btn btn-dark btn-outline-dark\" href=\"Other.html\">Other</a>"
         fi
   else
         echo "<a class=\"nav-link disabled\" href=\"Other.html\">Other</a>"
   fi
   echo "
   </li>
   </ul>
   </div>
   </div>
   </nav>"
}

#head of page $pageTitle
html_head(){
   echo "<!DOCTYPE html>
   <html lang=\"pl\">
   <head>
   <meta charset=\"utf-8\">
   <title>$1</title>
   <link rel=\"shortcut icon\" href=\"https://img.icons8.com/color-glass/344/internet.png\" />
   <link rel=\"stylesheet\" href=\"style.css\">
   <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.2.0-beta1/dist/css/bootstrap.min.css\" integrity=\"sha384-0evHe/X+R7YkIZDRvuzKMRqM+OrBnVFBL6DOitfPri4tjfHxaWutUpFmBp4vmVor\" crossorigin=\"anonymous\">
   <script src=\"https://cdn.jsdelivr.net/npm/bootstrap@5.2.0-beta1/dist/js/bootstrap.bundle.min.js\" integrity=\"sha384-pprn3073KE6tl6bjs2QrFaJGz5/SUsLqktiwsUTF55Jfv3qYSDhgCecCxMW52nD2\" crossorigin=\"anonymous\"></script>
   </head>
   <body class=\"bg-dark mt-5\">"
}

#create list of files for docs
# $pageTitle $files
docs_list_cat(){
    DataList=$(echo $2 | sed -e 's/\" \"/\":\"/g'| tr -d "\"");
    Field_Separator=$IFS
    IFS=:

   echo "
   <div class=\"table-responsive table-fixed \"><table class=\"table  table-sm  table-dark table-hover table-striped\">
  <thead class=\"\">
    <tr class=\"\">
      <th scope=\"col\">#</th>
      <th scope=\"col\">Name</th>
      <th scope=\"col\">Date of Modification</th>
      <th scope=\"col\">Full Path</th>
      <th scope=\"col\">Link</th>
    </tr>
  </thead>
  <tbody>"
   i=1

   for p in $DataList; do
      IFS=$Field_Separator
      if [[ "$OSTYPE" == "msys" ]]; then
      link=$(echo "$p" | sed 's/^\/[a-z]/\U&\:/g');
      else
      link=$(echo "$p");
      fi

      echo "<tr class=\"\">
      <th scope=\"row\">$i</th>"
      Field_Separator=$IFS
      IFS=:

      echo "<td>$(basename $p)</td>
      <td>$(date -r $p)</td>"

      IFS=$Field_Separator
      echo "<td>"$link"</td>
       <td><a class=\"btn btn-primary\" href=\"file://"$link"\">Link</a></td>
      </tr>"
      i=$((i+1));

      Field_Separator=$IFS
      IFS=:
   done
   IFS=$Field_Separator

  echo "
  </tbody>
   </table></div></body>"
}

#create list of files for images with additional column for minature
# $pageTitle $files
img_list_cat(){
    DataList=$(echo $2 | sed -e 's/\" \"/\":\"/g'| tr -d "\"");
    Field_Separator=$IFS
    IFS=:

   echo "
   <div class=\"table-responsive table-fixed \"><table class=\"table  table-sm  table-dark table-hover table-striped\">
  <thead class=\"\">
    <tr class=\"\">
      <th scope=\"col\">#</th>
      <th scope=\"col\">Minature</th>
      <th scope=\"col\">Name</th>
      <th scope=\"col\">Date of Modification</th>
      <th scope=\"col\">Full Path</th>
      <th scope=\"col\">Link</th>
    </tr>
  </thead>
  <tbody>"
   i=1

   for p in $DataList; do
      IFS=$Field_Separator
      if [[ "$OSTYPE" == "msys" ]]; then
      link=$(echo "$p" | sed 's/^\/[a-z]/\U&\:/g');
      else
      link=$(echo "$p");
      fi

      echo "<tr class=\"\">
      <th scope=\"row\">$i</th>
      <td><img src=\""$link"\" class=\"img-thumbnail w-100\" alt=\""$link"\"></td>"

      Field_Separator=$IFS
      IFS=:
      echo "<td>$(basename $p)</td>
      <td>$(date -r $p)</td>"
      IFS=$Field_Separator

      echo "<td>"$link"</td>
       <td><a class=\"btn btn-primary\" href=\"file://"$link"\">Link</a></td>
      </tr>"
      i=$((i+1));

      Field_Separator=$IFS
      IFS=:

   done
   IFS=$Field_Separator

  echo "
  </tbody>
   </table></div></body>"
}


# #check if output directory exists
# if [ ! -d "$output_dir" ]; then
#    mkdir -p "$output_dir"
# fi

cd "$output_dir";

custom_styling > style.css

#category printer
for i in "${!files[@]}"; do
   if [ "${files[$i]}" != "" ] ; then
         #create html file
         head=$(html_head $i)
         #create navbar
         nav=$(nav_menu $i file_extentions files);

         if [[ "$i" == "Images" ]]; then
            #create list of images
            list=$(img_list_cat $i "${files[$i]}");
         else
            #create list of files
            list=$(   $i "${files[$i]}");
         fi
         #list=$(docs_list_cat $i "${files[$i]}");

         echo "$head $nav $list" > $i.html;

         echo "</html>" >> $i.html
   fi
done

#here starts weird shit

for i in "${!file_extentions[@]}"; do
   if [ "${files[$i]}" != "" ] ; then
         for e in ${file_extentions[$i]}; do
         echo $e;
            if [[ "${files[$i]}" =~ "${e:1}" ]]; then
               #create html file
               head=$(html_head ${e:1})
               #create navbar
               nav=$(nav_menu "$e" file_extentions files);

               #filter only files with specific extension
               declare -a files_with_extention="";
               #echo "${files[$i]}";
               files_modified=$(echo "${files[$i]}" | tr '\n' ':');
               #echo "$files_modified";
               #need to change field seperator doesnt work otherwise
               Field_Separator=$IFS
               IFS=:
               for val in $files_modified; do
               #echo "$val";
                  if [[ "$val" =~ "${e:1}" ]]; then
                     files_with_extention+="\"$val\" ";
                  fi
               done

               #echo "$files_with_extention";
               files_with_extention=$(echo "$files_with_extention" | sed 's/ *\" $/\"/g');
               #echo $files_with_extention;

               IFS=$Field_Separator

               #files_with_extention=$(echo ${files[$i]} | egrep "$e");

               #echo "$files_with_extention";
               if [[ "$i" == "Images" ]]; then
                  #create list of images
                  list=$(img_list_cat "$e" "$files_with_extention");
               else
                  #create list of files
                  list=$(docs_list_cat "$e" "$files_with_extention");
               fi
               #list=$(docs_list_cat "${e:1}" "$files_with_extention");

               echo "$head $nav $list" > ${e:1}.html

               echo "</html>" >> ${e:1}.html
            fi
         done
   fi
done
IFS=$Field_Separator

#create Index.html
head=$(html_head "Index")
nav=$(nav_menu "Index" file_extentions files);
echo "$head $nav " > Index.html


#windows debug mode :)
#read -n 1 -r -s -p $'Press enter to continue...\n'
exit 1;
