WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS ScoreDifference
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    ru.Rank,
    ru.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount,
    CASE 
        WHEN rp.ScoreDifference IS NULL THEN 'No votes'
        ELSE rp.ScoreDifference
    END AS ScoreDifference,
    tt.TagName
FROM 
    RankedUsers ru
JOIN 
    RecentPosts rp ON ru.Id = rp.OwnerDisplayName
JOIN 
    TopTags tt ON tt.TagName IN (SELECT unnest(string_to_array(rp.Title, ' ')))  -- Using titles to determine the tags
ORDER BY 
    ru.Rank, rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;  -- Pagination logic
