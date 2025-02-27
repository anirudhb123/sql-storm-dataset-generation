WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS AuthorDisplayName,
        u.Reputation AS AuthorReputation,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Only consider posts created in the last year
    AND 
        p.Score > 0  -- Focus on posts with positive scores
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.TagCount,
        rp.AuthorDisplayName,
        rp.AuthorReputation
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10  -- Get the top 10 posts per type
),
PostStatistics AS (
    SELECT 
        hsp.PostId,
        hsp.Title,
        hsp.ViewCount,
        hsp.Score,
        hsp.TagCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount,
        MAX(hsp.CreationDate) AS LatestActivity
    FROM 
        HighScoringPosts hsp
    LEFT JOIN 
        Comments c ON c.PostId = hsp.PostId
    LEFT JOIN 
        Badges b ON b.UserId = hsp.AuthorDisplayName
    GROUP BY 
        hsp.PostId, hsp.Title, hsp.ViewCount, hsp.Score, hsp.TagCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.Score,
    ps.TagCount,
    ps.CommentCount,
    ps.BadgeCount,
    ps.LatestActivity,
    CASE 
        WHEN ps.Score >= 100 THEN 'Highly Popular'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS PopularityLevel
FROM 
    PostStatistics ps
ORDER BY 
    ps.ViewCount DESC, ps.Score DESC;
