WITH RecursiveMovie AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_note
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL AND
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'f%')  
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, t.season_nr
),
FilmInfo AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        m.total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.total_cast DESC) AS cast_rank
    FROM 
        RecursiveMovie m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, k.keyword, m.total_cast
)
SELECT 
    fi.title,
    fi.production_year,
    fi.keyword,
    fi.num_companies,
    fi.total_cast,
    fi.cast_rank,
    CASE 
        WHEN fi.cast_rank <= 5 THEN 'Top 5'
        WHEN fi.total_cast IS NULL THEN 'No Cast Data'
        ELSE 'Regular'
    END AS ranking_category
FROM 
    FilmInfo fi
WHERE 
    fi.production_year > 2000 AND 
    (fi.keyword <> 'No Keywords' OR fi.total_cast > 10)
ORDER BY 
    fi.production_year DESC, fi.cast_rank
LIMIT 100;