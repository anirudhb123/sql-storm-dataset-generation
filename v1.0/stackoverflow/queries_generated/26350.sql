WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS TotalComments,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.CreationDate DESC) AS PostRank,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS GlobalRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Within the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PopularTags AS (
    SELECT 
        tag, 
        COUNT(*) AS Popularity
    FROM (
        SELECT 
            UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS tag
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
    ) AS tags
    GROUP BY 
        tag
    ORDER BY 
        Popularity DESC
    LIMIT 10 -- Top 10 popular tags
)
SELECT 
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.TotalComments,
    rp.UpVotes,
    rp.DownVotes,
    pt.Popularity AS TagPopularity,
    CASE 
        WHEN rp.PostRank <= 5 THEN 'Top 5 for User'
        WHEN rp.GlobalRank <= 100 THEN 'Top 100 Globally'
        ELSE 'Other'
    END AS RankType
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.tag || '%'
WHERE 
    rp.PostRank <= 5 OR rp.GlobalRank <= 100 -- Filter based on ranks
ORDER BY 
    rp.CreationDate DESC;
