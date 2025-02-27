WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title at
    INNER JOIN 
        title a ON at.movie_id = a.id
    WHERE 
        at.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id, ak.name
    HAVING 
        COUNT(c.id) > 1
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.id) > 2
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        ta.actor_name,
        COALESCE(pk.keyword, 'No Keywords') AS keyword,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY ta.role_count DESC) AS actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON rm.title = (SELECT a.title FROM aka_title a WHERE a.movie_id = ta.movie_id)
    LEFT JOIN 
        PopularKeywords pk ON rm.id = pk.movie_id
)
SELECT 
    md.production_year,
    md.title,
    md.actor_name,
    md.keyword,
    CASE 
        WHEN md.actor_rank <= 3 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_category
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year, md.actor_rank;
