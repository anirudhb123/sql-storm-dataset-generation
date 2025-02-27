WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.title,
        mk.keyword
    FROM 
        TopMovies mt
    LEFT JOIN 
        movie_keyword mkw ON mt.movie_id = mkw.movie_id
    LEFT JOIN 
        keyword mk ON mkw.keyword_id = mk.id
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        CASE 
            WHEN p.gender = 'M' THEN 'Male'
            WHEN p.gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender_label
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.movie_id
    JOIN 
        name p ON ak.person_id = p.imdb_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.keyword,
    ad.actor_name,
    ad.gender_label
FROM 
    MovieKeywords md
JOIN 
    ActorDetails ad ON md.title = ad.movie_title AND md.production_year = ad.production_year
WHERE 
    ad.actor_name IS NOT NULL
ORDER BY 
    md.production_year DESC, md.movie_title ASC;
