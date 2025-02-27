WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY SUM(p.Score) DESC) AS ScoreRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
RecentVotes AS (
    SELECT 
        v.UserId,
        v.PostId,
        v.CreationDate,
        vt.Name AS VoteType
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '30 days'
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(rc.ClosedCount, 0) AS ClosedCount,
        COALESCE(cc.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS ClosedCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId = 10 
        GROUP BY 
            PostId
    ) rc ON p.Id = rc.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) cc ON p.Id = cc.PostId
),
FinalReport AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalScore,
        p.Title,
        p.ViewCount,
        p.Score,
        p.ClosedCount,
        p.CommentCount,
        COALESCE(rv.VoteType, 'No Votes') AS RecentVoteType,
        rv.CreationDate AS RecentVoteDate
    FROM 
        UserPostStats ups
    JOIN 
        PostDetails p ON ups.UserId = p.OwnerUserId
    LEFT JOIN 
        RecentVotes rv ON p.PostId = rv.PostId AND rv.UserId = ups.UserId
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    Title,
    ViewCount,
    Score,
    CASE 
        WHEN ClosedCount > 0 THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus,
    CommentCount,
    RecentVoteType,
    RecentVoteDate
FROM 
    FinalReport
WHERE 
    TotalScore > 50
ORDER BY 
    TotalScore DESC, 
    PostCount DESC;
