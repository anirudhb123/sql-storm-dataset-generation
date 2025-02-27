WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, u.DisplayName, p.PostTypeId
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerUserId, 
        OwnerDisplayName, 
        PostTypeId, 
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    TRP.*, 
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(VoteCount, 0) AS TotalVotes
FROM 
    TopRankedPosts TRP
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) AS B ON TRP.OwnerUserId = B.UserId
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS VoteCount
    FROM 
        Votes
    WHERE 
        VoteTypeId IN (2, 3)
    GROUP BY 
        PostId
) AS V ON TRP.PostId = V.PostId
ORDER BY 
    UpVotes DESC, 
    CommentCount DESC;
