WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 questions
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close or reopen events
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.TotalUpVotes,
    rp.TotalDownVotes,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    cr.CloseReasonCount,
    cr.CloseReasons
FROM 
    RankedPosts rp
LEFT JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
WHERE 
    rp.PostRank = 1 -- Only taking the highest scoring post for each user
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100; -- Limit the number of results
