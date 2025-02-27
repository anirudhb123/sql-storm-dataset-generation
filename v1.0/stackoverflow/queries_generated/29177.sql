WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankScore,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
             unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS TagName,
             Id
         FROM 
             Posts) t ON t.Id = p.Id
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id, u.DisplayName
), HighScoringPosts AS (
    SELECT 
        PostId, 
        Title, 
        Body, 
        OwnerDisplayName, 
        CreationDate, 
        ViewCount, 
        Score, 
        RankScore, 
        TagList
    FROM 
        RankedPosts
    WHERE 
        RankScore <= 5
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.Body,
    hsp.OwnerDisplayName,
    hsp.CreationDate,
    hsp.ViewCount,
    hsp.Score,
    hsp.TagList,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COALESCE(MAX(b.Date), 'N/A') AS LastBadgeDate
FROM 
    HighScoringPosts hsp
LEFT JOIN 
    Comments c ON c.PostId = hsp.PostId
LEFT JOIN 
    Votes v ON v.PostId = hsp.PostId
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = hsp.PostId)
GROUP BY 
    hsp.PostId, hsp.Title, hsp.Body, hsp.OwnerDisplayName, hsp.CreationDate, hsp.ViewCount, hsp.Score, hsp.TagList
ORDER BY 
    hsp.Score DESC, hsp.ViewCount DESC;

