WITH RecursivePostCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        CAST(1 AS INT) AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.OwnerUserId,
        a.AcceptedAnswerId,
        rp.Level + 1
    FROM
        Posts a
    INNER JOIN RecursivePostCTE rp ON a.ParentId = rp.PostId
    WHERE
        a.PostTypeId = 2 -- Answers
),
UserPostStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(v.Score, 0)) AS TotalScore,
        LEAD(SUM(COALESCE(v.Score, 0))) OVER (ORDER BY SUM(COALESCE(v.Score, 0)) DESC) AS NextUserScore
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    GROUP BY
        u.Id, u.DisplayName
),
ClosedPostStats AS (
    SELECT
        p.Id,
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ClosureTiming
    FROM
        Posts p
    INNER JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.PostHistoryTypeId = 10 -- Post Closed
),
RecentPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(c.Count, 0) AS CommentCount,
        COALESCE(vs.TotalScore, 0) AS VoteScore
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT
            PostId, COUNT(*) AS Count
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN
        UserPostStats vs ON u.Id = vs.UserId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '30 days'
)
SELECT
    rp.PostId,
    rp.Title AS QuestionTitle,
    rp.OwnerUserId,
    up.DisplayName AS OwnerName,
    rp.Level AS AnswerLevel,
    us.PostCount AS UserPostCount,
    us.TotalScore AS UserTotalScore,
    cp.ClosedDate,
    cp.ClosedBy,
    cp.CloseReason,
    rp2.Title AS AcceptedAnswerTitle,
    rp2.OwnerUserId AS AcceptedAnswerOwner,
    rp2.Creator AS AcceptedBy
FROM
    RecursivePostCTE rp
LEFT JOIN 
    UserPostStats us ON rp.OwnerUserId = us.UserId
LEFT JOIN 
    ClosedPostStats cp ON rp.PostId = cp.Id
LEFT JOIN
    Posts rp2 ON rp.AcceptedAnswerId = rp2.Id
WHERE
    us.TotalScore > COALESCE(us.NextUserScore, 0) -- Filter to only show top user posts
ORDER BY
    rp.Title, rp.Level;
