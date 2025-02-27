WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON p.Id = V.PostId
    LEFT JOIN 
        Comments C ON p.Id = C.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, U.DisplayName, p.Title, p.CreationDate, p.PostTypeId
), PostStatistics AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        CASE 
            WHEN Rank = 1 THEN 'Top'
            ELSE 'Other'
        END AS PostCategory
    FROM 
        RankedPosts
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.OwnerDisplayName,
    ps.UpVotes,
    ps.DownVotes,
    ps.CommentCount,
    ps.PostCategory,
    COALESCE(BadgeCounts.BadgeCount, 0) AS BadgeCount
FROM 
    PostStatistics ps
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) AS BadgeCounts ON ps.OwnerDisplayName = BadgeCounts.UserId
WHERE 
    ps.UpVotes > 5
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC;
