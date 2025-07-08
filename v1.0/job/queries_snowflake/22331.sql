
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        aka_title.kind_id,
        ROW_NUMBER() OVER (PARTITION BY title.kind_id ORDER BY title.production_year DESC) AS rank
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    WHERE 
        aka_title.production_year IS NOT NULL
), 
ActorMovies AS (
    SELECT 
        aki.person_id, 
        aki.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name AS aki
    JOIN 
        cast_info AS ci ON aki.person_id = ci.person_id
    GROUP BY 
        aki.person_id, 
        aki.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
), 
MovieRankings AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.kind_id,
        rm.rank,
        am.movie_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.person_id
    WHERE 
        am.movie_count >= 3 OR am.movie_count IS NULL
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mk.movie_id,
    mk.keywords,
    mr.title,
    mr.rank,
    CASE 
        WHEN mr.movie_count IS NOT NULL THEN 'Main Actor'
        ELSE 'Extra'
    END AS role_category,
    COALESCE(info.info, 'No information available') AS additional_info
FROM 
    MovieRankings mr
LEFT JOIN 
    MovieKeywords mk ON mr.movie_id = mk.movie_id
LEFT JOIN 
    movie_info info ON mr.movie_id = info.movie_id AND info.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%runtime%')
WHERE 
    mr.rank <= 10
ORDER BY 
    mr.rank ASC, 
    mk.keywords DESC NULLS LAST;
