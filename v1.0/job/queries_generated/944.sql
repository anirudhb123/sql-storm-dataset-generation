WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank,
        COALESCE(mci.note, 'No Note') AS company_note,
        COUNT(DISTINCT mk.keyword) OVER (PARTITION BY a.id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mci ON a.id = mci.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
),
PopularActors AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        COUNT(ca.person_id) AS appearances
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.movie_id, ak.name
    HAVING 
        COUNT(ca.person_id) > 1
),
MovieActorDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.company_note,
        pa.actor_name,
        pa.appearances
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularActors pa ON rm.id = pa.movie_id
)
SELECT 
    mad.title,
    mad.production_year,
    mad.company_note,
    mad.actor_name,
    COALESCE(mad.appearances, 0) AS appearances,
    CASE 
        WHEN mad.appearances IS NULL THEN 'Unknown Actor'
        ELSE mad.actor_name
    END AS display_actor
FROM 
    MovieActorDetails mad
WHERE 
    mad.rank <= 5
ORDER BY 
    mad.production_year DESC, mad.appearances DESC;
