WITH TitleKeywords AS (
    SELECT mt.title AS movie_title, k.keyword AS movie_keyword, mt.production_year
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE mt.production_year BETWEEN 2000 AND 2023
),
CastDetails AS (
    SELECT ak.name AS actor_name, at.title AS movie_title, at.production_year, cr.role AS character_name
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN aka_title at ON ci.movie_id = at.id
    JOIN role_type cr ON ci.role_id = cr.id
    WHERE ak.name IS NOT NULL
),
CompanyDetails AS (
    SELECT cn.name AS company_name, mt.title AS movie_title, mt.production_year
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN aka_title mt ON mc.movie_id = mt.id
    WHERE cn.country_code = 'USA'
),
GenreStats AS (
    SELECT kt.kind AS genre, COUNT(mt.id) AS movie_count, MIN(mt.production_year) AS first_year, MAX(mt.production_year) AS last_year
    FROM aka_title mt
    JOIN kind_type kt ON mt.kind_id = kt.id
    GROUP BY kt.kind
    ORDER BY movie_count DESC
),
FinalOutput AS (
    SELECT 
        TD.movie_title,
        TD.actor_name,
        TD.character_name,
        CD.company_name,
        CD.production_year,
        TK.movie_keyword,
        GS.genre,
        GS.movie_count
    FROM CastDetails TD
    LEFT JOIN CompanyDetails CD ON TD.movie_title = CD.movie_title AND TD.production_year = CD.production_year
    LEFT JOIN TitleKeywords TK ON TD.movie_title = TK.movie_title
    LEFT JOIN GenreStats GS ON TK.movie_keyword = GS.genre
)
SELECT *
FROM FinalOutput
WHERE movie_title IS NOT NULL
ORDER BY production_year DESC, movie_title;
