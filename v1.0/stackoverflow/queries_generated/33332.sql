WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 -- Only Questions
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1
    GROUP BY
        u.Id, u.DisplayName
    HAVING
        COUNT(DISTINCT p.Id) > 5 -- Users with more than 5 questions
),
TopQuestions AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        tu.DisplayName AS TopUser
    FROM
        RankedPosts rp
    JOIN
        TopUsers tu ON rp.PostId IN (
            SELECT p.Id
            FROM Posts p
            WHERE p.OwnerUserId = tu.UserId AND p.PostTypeId = 1
        )
    WHERE
        rp.RankByScore <= 3 -- Top 3 questions per user
),
RecentHistory AS (
    SELECT
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title,
        ph.UserDisplayName,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM
        PostHistory ph
    JOIN
        Posts p ON ph.PostId = p.Id
    WHERE
        ph.PostHistoryTypeId IN (10, 11, 12, 13) -- Close, Reopen, Delete, Undelete actions
)
SELECT
    tq.Title,
    tq.CreationDate AS QuestionDate,
    tq.Score,
    tq.ViewCount,
    tq.AnswerCount,
    COALESCE(rh.HistoryDate, 'No History') AS LastActionDate,
    rh.UserDisplayName AS LastActionedBy,
    CASE 
        WHEN rh.PostHistoryTypeId IS NOT NULL THEN
            CASE 
                WHEN rh.PostHistoryTypeId = 10 THEN 'Closed'
                WHEN rh.PostHistoryTypeId = 11 THEN 'Reopened'
                WHEN rh.PostHistoryTypeId = 12 THEN 'Deleted'
                WHEN rh.PostHistoryTypeId = 13 THEN 'Undeleted'
            END
        ELSE 'Active'
    END AS CurrentStatus,
    tq.TopUser
FROM
    TopQuestions tq
LEFT JOIN
    RecentHistory rh ON tq.PostId = rh.PostId AND rh.rn = 1
ORDER BY
    tq.Score DESC
LIMIT 50;
