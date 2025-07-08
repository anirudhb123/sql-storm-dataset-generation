
WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ct.kind AS role_name,
        CAST(ci.nr_order AS INTEGER) AS character_order,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ci.nr_order) AS role_rank,
        at.id AS movie_id
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        at.production_year > 2000
),
KeywordStats AS (
    SELECT 
        mk.movie_id, 
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mk.movie_id
),
MovieRank AS (
    SELECT 
        md.movie_title, 
        md.production_year, 
        md.actor_name,
        md.role_name,
        md.character_order,
        ks.keyword_count,
        DENSE_RANK() OVER (ORDER BY ks.keyword_count DESC) AS keyword_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordStats ks ON md.movie_id = ks.movie_id
)
SELECT 
    mr.movie_title,
    mr.production_year,
    LISTAGG(mr.actor_name || ' (' || mr.role_name || ')' , ', ') WITHIN GROUP (ORDER BY mr.character_order) AS cast_details,
    CASE 
        WHEN mr.keyword_count IS NULL THEN 'No Keywords'
        ELSE CAST(mr.keyword_count AS STRING)
    END AS keyword_stats,
    mr.keyword_rank
FROM 
    MovieRank mr
GROUP BY 
    mr.movie_title, mr.production_year, mr.keyword_count, mr.keyword_rank
HAVING 
    mr.keyword_rank <= 5
ORDER BY 
    mr.production_year DESC, 
    mr.keyword_rank;
