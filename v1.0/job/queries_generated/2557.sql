WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        mk.keyword, 
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY mk.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
ActorDetails AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        COUNT(ci.movie_id) AS movies_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
   HAVING 
        COUNT(ci.movie_id) > 5
), 
HighRatedMovies AS (
    SELECT 
        m.id AS movie_id,
        MAX(CASE WHEN it.info_type_id IN (1, 2) THEN it.info END) AS rating -- Assuming 1 and 2 correspond to ratings
    FROM 
        title m
    LEFT JOIN 
        movie_info it ON m.id = it.movie_id
    WHERE 
        it.info IS NOT NULL
    GROUP BY 
        m.id
    HAVING 
        MAX(CASE WHEN it.info_type_id IN (1, 2) THEN it.info END) >= '7.0' -- Minimum rating threshold
)
SELECT 
    md.title,
    md.production_year,
    md.kind_id,
    hd.actor_name,
    hd.movies_count,
    md.keyword,
    CASE 
        WHEN hd.movies_count IS NULL THEN 'No movies'
        ELSE hd.movies_count::text
    END AS movie_count_text,
    COALESCE(md.company_names, '{}') AS companies
FROM 
    MovieDetails md
JOIN 
    HighRatedMovies hm ON md.title = hm.movie_id
LEFT JOIN 
    ActorDetails hd ON md.movie_id = hd.actor_id
WHERE 
    md.keyword_rank <= 3
ORDER BY 
    md.production_year DESC, hd.movies_count DESC;
