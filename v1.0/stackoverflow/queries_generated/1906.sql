WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AnswerCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate > NOW() - INTERVAL '1 year'
), 
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts p ON U.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
), 
ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
), 
MostActive AS (
    SELECT 
        u.Id AS UserId, 
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS VoteCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id
)
SELECT 
    r.Id AS PostId,
    r.Title,
    r.ViewCount,
    r.CreationDate,
    r.AnswerCount,
    tu.TotalQuestions,
    tu.TotalViews,
    COALESCE(cp.CloseReasons, 'No Close Reasons') AS CloseReasons,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    ma.VoteCount,
    ma.CloseVotes
FROM 
    RankedPosts r
LEFT JOIN 
    TopUsers tu ON r.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON r.Id = cp.PostId
LEFT JOIN 
    MostActive ma ON r.OwnerUserId = ma.UserId
WHERE 
    r.rn = 1
ORDER BY 
    r.ViewCount DESC, 
    r.CreationDate DESC;
