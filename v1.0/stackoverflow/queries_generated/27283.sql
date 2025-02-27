WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        RANK() OVER (ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS TagName
        ) AS t ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId = 1  -- Filtering for Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT Id FROM Users WHERE DisplayName = rp.OwnerDisplayName)
    LEFT JOIN 
        Votes v ON v.PostId = rp.Id
    GROUP BY 
        rp.Id, rp.Title, rp.Body, rp.CreationDate, rp.OwnerDisplayName, rp.Score, rp.CommentCount
)
SELECT 
    fp.Title,
    fp.Body,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Tags,
    fp.Score,
    fp.CommentCount,
    fp.BadgeCount,
    fp.UpVoteCount,
    fp.RankScore
FROM 
    FilteredPosts fp
WHERE 
    fp.RankScore <= 10  -- Get the top 10 questions by score
ORDER BY 
    fp.RankScore;
