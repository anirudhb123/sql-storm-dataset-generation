
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Ranking
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),

TrimmedTags AS (
    SELECT 
        PostId,
        STRING_AGG(LTRIM(RTRIM(t.TagName)), ', ') AS CleanedTags
    FROM 
        RankedPosts rp
    CROSS APPLY 
        string_split(rp.Tags, '>') AS raw_tags
    JOIN 
        Tags t ON LTRIM(RTRIM(raw_tags.value)) = t.TagName
    GROUP BY 
        PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    tt.CleanedTags,
    CASE 
        WHEN rp.Ranking <= 5 THEN 'Top Performer'
        WHEN rp.Score > 10 THEN 'Moderate Performer'
        ELSE 'Needs Attention'
    END AS PerformanceCategory
FROM 
    RankedPosts rp
JOIN 
    TrimmedTags tt ON rp.PostId = tt.PostId
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;
