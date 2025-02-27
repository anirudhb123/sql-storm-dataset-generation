WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.Id = ANY (string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month' 
    GROUP BY 
        p.Id
),

PostStatistics AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        CommentCount,
        UpVotes,
        DownVotes,
        Tags
    FROM 
        RankedPosts
    WHERE 
        rn <= 5 -- limiting to the newest 5 posts per type
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ARRAY_TO_STRING(ps.Tags, ', ') AS Tags,
    COALESCE(
        (SELECT 
            STRING_AGG(CONCAT(u.DisplayName, ': ', b.Name), '; ')
         FROM 
            Badges b 
         JOIN 
            Users u ON u.Id = b.UserId 
         WHERE 
            u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = ps.PostId)
         GROUP BY DisplayName), 
        'No badges') AS UserBadges
FROM 
    PostStatistics ps
ORDER BY 
    ps.CreationDate DESC;
