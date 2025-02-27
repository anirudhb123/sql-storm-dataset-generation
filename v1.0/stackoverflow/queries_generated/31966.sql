WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0) AS NetVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
         FROM 
            Votes 
         GROUP BY 
            PostId) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Author,
        CreationDate,
        Score,
        NetVotes,
        CommentCount,
        RANK() OVER (ORDER BY NetVotes DESC, CreationDate ASC) AS Rank
    FROM 
        RankedPosts
    WHERE 
        rn = 1 -- Get only top-ranked post for each post type
)
SELECT 
    tp.*,
    CASE 
        WHEN bp.UserId IS NOT NULL THEN 'Has Badge'
        ELSE 'No Badge'
    END AS BadgeStatus,
    (SELECT STRING_AGG(TAG.TagName, ', ') 
     FROM Tags TAG 
     JOIN STRING_SPLIT(p.Tags, '<>') AS T ON TAG.TagName = T.value
     WHERE p.Id = tp.PostId) AS RelatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    Badges bp ON bp.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank, tp.Score DESC;
