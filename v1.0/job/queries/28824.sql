
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ka.name, ', ') AS actors,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'No Company') AS company_names,
        COUNT(DISTINCT ci.person_role_id) AS num_roles
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY mt.id, mt.title, mt.production_year
),
HighProfileMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.actors,
        md.keywords,
        md.company_names,
        md.num_roles
    FROM MovieDetails md
    WHERE md.production_year > 2000 AND md.num_roles > 5
)
SELECT 
    hpm.movie_id,
    hpm.movie_title,
    hpm.production_year,
    hpm.actors,
    hpm.keywords,
    hpm.company_names
FROM HighProfileMovies hpm
ORDER BY hpm.production_year DESC, hpm.num_roles DESC;
