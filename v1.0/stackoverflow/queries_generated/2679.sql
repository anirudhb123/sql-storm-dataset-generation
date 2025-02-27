WITH RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY 
        p.Id, u.Id
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerName, 
        CreationDate, 
        CommentCount,
        UpVoteCount, 
        DownVoteCount,
        UserPostRank
    FROM 
        RecentActivity
    WHERE 
        UserPostRank <= 5
)
SELECT 
    p.Id,
    p.Title,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPostCount,
    COALESCE(MAX(b.Name), 'No Badge') AS HighestBadge,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
FROM 
    TopPosts p
LEFT JOIN 
    PostLinks pl ON p.PostId = pl.PostId
LEFT JOIN 
    Badges b ON p.OwnerPostId = b.UserId 
             AND b.Class = (SELECT MIN(Class) FROM Badges WHERE UserId = p.OwnerPostId)
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
GROUP BY 
    p.Id
ORDER BY 
    CommentCount DESC, UpVoteCount DESC;
