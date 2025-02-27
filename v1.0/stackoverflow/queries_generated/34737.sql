WITH RecursivePostChain AS (
    -- CTE to retrieve all post links recursively
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        1 AS Depth
    FROM 
        PostLinks pl
    WHERE 
        pl.LinkTypeId = 3  -- Focus on duplicates

    UNION ALL

    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        rpc.Depth + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RecursivePostChain rpc ON pl.PostId = rpc.RelatedPostId
    WHERE 
        pl.LinkTypeId = 3
),
UserReputation AS (
    -- CTE to summarize user reputation by their posts
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RankedPosts AS (
    -- CTE to rank posts based on their view count
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
),
ActiveUserStats AS (
    -- CTE to summarize actions and activities of users
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(p.CreationDate) AS LastActiveDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Within the last year
    GROUP BY 
        u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(rp.TotalScore, 0) AS ReputationScore,
    COALESCE(ups.PostCount, 0) AS UserPostCount,
    COALESCE(ups.CommentCount, 0) AS UserCommentCount,
    COALESCE(ups.LastActiveDate, 'No Activity') AS LastActivePeriod,
    COALESCE(rp.TotalUpVotes, 0) - COALESCE(rp.TotalDownVotes, 0) AS VoteBalance,
    COUNT(DISTINCT r.RelatedPostId) AS DuplicateCount
FROM 
    Users u
LEFT JOIN 
    UserReputation rp ON u.Id = rp.UserId
LEFT JOIN 
    ActiveUserStats ups ON u.Id = ups.UserId
LEFT JOIN 
    RecursivePostChain r ON u.Id IN (
        SELECT 
            DISTINCT p.OwnerUserId
        FROM 
            Posts p
        JOIN 
            PostLinks pl ON p.Id = pl.PostId
        WHERE 
            pl.LinkTypeId = 3 -- only duplicates
    )
WHERE 
    u.Reputation > 1000  -- Filter based on reputation
GROUP BY 
    u.Id, ups.PostCount, ups.CommentCount, rp.TotalScore, ups.LastActiveDate
ORDER BY 
    ReputationScore DESC, DuplicateCount DESC;
