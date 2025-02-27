WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.PostTypeId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Starting from Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.PostTypeId,
        p.CreationDate,
        rp.Level + 1
    FROM 
        Posts p
    JOIN 
        RecursivePosts rp ON p.ParentId = rp.Id
    WHERE 
        p.PostTypeId = 2 -- Only include Answers
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY 
        p.Id, p.Title, u.DisplayName
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000 -- Filter high reputation users
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) >= 50 -- Users must have posts with a minimum score
),
EnhancedResults AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.AcceptedAnswerId,
        rp.CreationDate,
        rp.Level,
        COALESCE(rp.CommentCount, 0) AS CommentCount,
        COALESCE(rp.UpVoteCount, 0) AS UpVoteCount,
        tu.DisplayName AS TopUserDisplayName,
        tu.TotalScore,
        tu.PostCount
    FROM 
        RecursivePosts rp
    LEFT JOIN 
        RankedPosts r ON r.PostId = rp.Id
    LEFT JOIN 
        TopUsers tu ON tu.UserId = rp.OwnerUserId
)

SELECT 
    e.PostId,
    e.Title,
    e.OwnerUserId,
    e.Level,
    e.CommentCount,
    e.UpVoteCount,
    e.TopUserDisplayName,
    e.TotalScore,
    e.PostCount
FROM 
    EnhancedResults e
WHERE 
    e.UpVoteCount > 0 
    AND e.CommentCount < 5 
ORDER BY 
    e.TotalScore DESC, e.PostId
OPTION (MAXRECURSION 100);
