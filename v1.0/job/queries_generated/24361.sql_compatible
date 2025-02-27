
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(m.production_year AS VARCHAR)
        END AS production_year_label,
        COALESCE(c.name, 'Unknown Company') AS production_company,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_actors,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
film_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.production_year_label,
        mh.production_company,
        COALESCE(ca.unique_actors, 0) AS total_actors,
        COALESCE(ca.roles_count, 0) AS total_roles,
        (mh.production_year_label || ' - ' || mh.production_company) AS film_description
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
)
SELECT 
    fi.movie_id,
    fi.title,
    fi.production_year_label,
    fi.production_company,
    fi.total_actors,
    fi.total_roles,
    fi.film_description
FROM 
    film_info fi
WHERE 
    fi.total_roles > 3
ORDER BY 
    fi.production_year DESC,
    fi.total_actors DESC
LIMIT 10;
