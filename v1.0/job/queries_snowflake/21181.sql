
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    WHERE 
        c.note IS NULL OR c.note NOT LIKE '%uncredited%'
    GROUP BY 
        c.movie_id
),
MovieGenerals AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.id AND cc.status_id IS NULL) AS pending_cast_count
    FROM 
        aka_title m
    LEFT JOIN ActorCounts ac ON m.id = ac.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year, ac.actor_count
),
HighestRated AS (
    SELECT 
        mi.movie_id,
        AVG(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(mi.info AS DECIMAL) END) AS average_rating
    FROM 
        movie_info mi
    JOIN 
        movie_companies mc ON mi.movie_id = mc.movie_id
    JOIN 
        movie_info_idx mii ON mi.id = mii.id
    GROUP BY 
        mi.movie_id
),
FinalReport AS (
    SELECT 
        mg.movie_id,
        mg.title,
        mg.production_year,
        mg.actor_count,
        mg.keyword_count,
        mg.pending_cast_count,
        COALESCE(hr.average_rating, 0) AS average_rating
    FROM 
        MovieGenerals mg
    LEFT JOIN HighestRated hr ON mg.movie_id = hr.movie_id
    WHERE 
        mg.actor_count > (SELECT AVG(actor_count) FROM MovieGenerals)
    ORDER BY 
        mg.production_year DESC, average_rating DESC
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.keyword_count,
    fr.pending_cast_count,
    fr.average_rating,
    CASE 
        WHEN fr.average_rating = 0 THEN 'No Ratings'
        WHEN fr.average_rating > 8 THEN 'Highly Rated'
        WHEN fr.average_rating BETWEEN 5 AND 8 THEN 'Moderately Rated'
        ELSE 'Low Rated' 
    END AS rating_category
FROM 
    FinalReport fr
WHERE 
    fr.actor_count = (
      SELECT MAX(actor_count) 
      FROM FinalReport
    )
    OR fr.keyword_count > 5
    OR fr.pending_cast_count > 0
ORDER BY 
    fr.actor_count DESC, fr.keyword_count DESC;
