WITH ActorDetails AS (
    SELECT 
        akn.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT tt.title, ', ') AS movies_titles
    FROM 
        aka_name akn
    JOIN 
        cast_info ci ON akn.person_id = ci.person_id
    JOIN 
        aka_title tt ON ci.movie_id = tt.movie_id
    WHERE 
        akn.name IS NOT NULL
    GROUP BY 
        akn.name
), 
GenreCounts AS (
    SELECT 
        tt.title,
        COUNT(DISTINCT kt.keyword) AS genre_count
    FROM 
        aka_title tt
    JOIN 
        movie_keyword mk ON tt.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        tt.title
), 
CompanyDetails AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS produced_movies
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    GROUP BY 
        cn.name
) 
SELECT 
    ad.actor_name,
    ad.total_movies,
    ad.movies_titles,
    gc.genre_count,
    cd.company_name,
    cd.produced_movies
FROM 
    ActorDetails ad
LEFT JOIN 
    GenreCounts gc ON ad.movies_titles LIKE '%' || gc.title || '%'
LEFT JOIN 
    CompanyDetails cd ON ad.movies_titles LIKE '%' || cd.company_name || '%'
ORDER BY 
    ad.total_movies DESC, 
    gc.genre_count DESC;
