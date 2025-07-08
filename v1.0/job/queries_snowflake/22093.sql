
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS num_cast_members,
        RANK() OVER(PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_by_cast
    FROM title
    LEFT JOIN cast_info ON title.id = cast_info.movie_id
    GROUP BY title.id, title.title, title.production_year
),
movie_keywords AS (
    SELECT 
        movie_id,
        LISTAGG(keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords
    FROM movie_keyword
    JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY movie_id
),
director_info AS (
    SELECT 
        ci.movie_id,
        ak.name AS director_name,
        ak.id AS director_id
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rt ON ci.role_id = rt.id
    WHERE rt.role = 'director'
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
combined_info AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_cast_members,
        mk.keywords,
        di.director_name,
        ci.company_name,
        ci.company_type,
        COALESCE(NULLIF(rm.rank_by_cast, 0), 999) AS adjusted_rank 
    FROM
        ranked_movies rm
    LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN director_info di ON rm.movie_id = di.movie_id
    LEFT JOIN company_info ci ON rm.movie_id = ci.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    num_cast_members,
    keywords,
    director_name,
    company_name,
    company_type,
    adjusted_rank
FROM 
    combined_info
WHERE 
    production_year >= 2000 
    AND (num_cast_members > 0 OR director_name IS NOT NULL) 
ORDER BY 
    adjusted_rank ASC, 
    num_cast_members DESC, 
    production_year DESC
LIMIT 50;
