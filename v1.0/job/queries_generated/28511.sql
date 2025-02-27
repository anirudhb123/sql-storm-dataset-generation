WITH MovieDetails AS (
    SELECT 
        T.title AS movie_title,
        T.production_year,
        COALESCE(CNT.kind, 'Unknown') AS movie_type,
        ARRAY_AGG(DISTINCT CN.name) AS company_names,
        ARRAY_AGG(DISTINCT K.keyword) AS movie_keywords,
        STRING_AGG(DISTINCT A.name, ', ') AS actors
    FROM title T
    LEFT JOIN movie_companies MC ON T.id = MC.movie_id
    LEFT JOIN company_name CN ON MC.company_id = CN.id
    LEFT JOIN kind_type CNT ON MC.company_type_id = CNT.id
    LEFT JOIN cast_info CI ON T.id = CI.movie_id
    LEFT JOIN aka_name A ON CI.person_id = A.person_id
    LEFT JOIN movie_keyword MK ON T.id = MK.movie_id
    LEFT JOIN keyword K ON MK.keyword_id = K.id
    GROUP BY T.id, T.title, T.production_year, CNT.kind
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_type,
        company_names,
        movie_keywords,
        actors,
        RANK() OVER (ORDER BY production_year DESC) AS rank_order
    FROM MovieDetails
)
SELECT 
    movie_title,
    production_year,
    movie_type,
    company_names,
    movie_keywords,
    actors,
    rank_order
FROM RankedMovies
WHERE rank_order <= 10
ORDER BY production_year DESC;
