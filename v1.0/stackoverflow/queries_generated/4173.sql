WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(p.Score), 0) AS TotalScore,
        RANK() OVER (ORDER BY COALESCE(SUM(p.Score), 0) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN (SELECT Name FROM CloseReasonTypes WHERE Id = CAST(ph.Comment AS INT))
            ELSE NULL
        END AS CloseReason,
        ph.UserId AS ModifierUserId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12)
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        (
            SELECT 
                COUNT(*) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = p.Id AND 
                v.VoteTypeId = 2
        ) AS UpVotes,
        (
            SELECT 
                COUNT(*) 
            FROM 
                Votes v 
            WHERE 
                v.PostId = p.Id AND 
                v.VoteTypeId = 3
        ) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.ScoreRank,
    pm.PostId,
    pm.Title AS PostTitle,
    pm.CreationDate AS PostCreationDate,
    pm.CommentCount,
    pm.UniqueVoteCount,
    pm.UpVotes,
    pm.DownVotes,
    phd.CloseReason,
    phd.ModifierUserId
FROM 
    UserPostStats ups
LEFT JOIN PostMetrics pm ON pm.PostId IN (
    SELECT PostId FROM PostHistory WHERE UserId = ups.UserId
)
LEFT JOIN PostHistoryDetails phd ON pm.PostId = phd.PostId
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.ScoreRank, pm.CommentCount DESC NULLS LAST;
