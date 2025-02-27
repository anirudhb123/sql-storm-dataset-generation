WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(COALESCE(CAST(v.BountyAmount AS FLOAT), 0)) AS AvgBounty,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id 
    GROUP BY 
        u.Id
),
CloseReasons AS (
    SELECT 
        p.Id AS PostId,
        MIN(ph.CreationDate) AS FirstClosedDate,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasonNames
    FROM 
        Posts p
    INNER JOIN 
        PostHistory ph ON p.Id = ph.PostId
    INNER JOIN 
        CloseReasonTypes ctr ON ctr.Id = CAST(ph.Comment AS INT)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.Id
),
DetailedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(cr.FirstClosedDate, 'No Closures') AS FirstClosedDate,
        COALESCE(cr.LastClosedDate, 'No Closures') AS LastClosedDate,
        COALESCE(cr.CloseReasonNames, 'No Reasons') AS ClosureReasons,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentsCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        CloseReasons cr ON p.Id = cr.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, cr.FirstClosedDate, cr.LastClosedDate, cr.CloseReasonNames
),
FinalResults AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.PostCount,
        us.QuestionCount,
        us.AnswerCount,
        us.AvgBounty,
        us.TotalUpVotes,
        us.TotalDownVotes,
        dp.PostId,
        dp.Title,
        dp.FirstClosedDate,
        dp.LastClosedDate,
        dp.ClosureReasons,
        dp.CommentsCount,
        dp.ViewRank
    FROM 
        UserStats us
    LEFT JOIN 
        DetailedPosts dp ON us.UserId = dp.OwnerUserId
    WHERE 
        us.Reputation > 1000
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgBounty,
    TotalUpVotes,
    TotalDownVotes,
    PostId,
    Title,
    FirstClosedDate,
    LastClosedDate,
    ClosureReasons,
    CommentsCount,
    ViewRank
FROM 
    FinalResults 
ORDER BY 
    AvgBounty DESC NULLS LAST, 
    PostCount DESC, 
    ViewRank ASC
LIMIT 100;
