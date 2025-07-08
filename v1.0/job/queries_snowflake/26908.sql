
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    JOIN 
        cast_info ca ON mt.id = ca.movie_id
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
MovieKeywords AS (
    SELECT 
        k.keyword,
        mk.movie_id
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
PopularKeywords AS (
    SELECT 
        keyword,
        COUNT(movie_id) AS keyword_count
    FROM 
        MovieKeywords
    GROUP BY 
        keyword
    HAVING 
        COUNT(movie_id) > 5
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.actor_names,
        pk.keyword,
        pk.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        PopularKeywords pk ON rm.movie_id IN (SELECT movie_id FROM MovieKeywords WHERE keyword = pk.keyword)
    WHERE 
        rm.rank_by_cast <= 10
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.actor_names,
    fr.keyword,
    fr.keyword_count
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.total_cast DESC;
