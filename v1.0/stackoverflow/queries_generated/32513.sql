WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.OwnerUserId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
TopContributors AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        AcceptedAnswersCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        UserPostStats
),
PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        v.CreationDate AS VoteDate
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
            MAX(CreationDate) AS CreationDate
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
),
MostVotedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY UpVotes DESC, Score DESC) AS VoteRank
    FROM 
        PostsWithVotes
)
SELECT 
    postRank.PostId,
    postRank.Title,
    postRank.UpVotes,
    postRank.DownVotes,
    contributors.DisplayName,
    contributors.PostCount,
    contributors.QuestionCount,
    contributors.AcceptedAnswersCount,
    CASE 
        WHEN postRank.UpVotes > postRank.DownVotes THEN 'Positive'
        WHEN postRank.UpVotes < postRank.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    COALESCE(hierarchy.Level, -1) AS PostLevel
FROM 
    MostVotedPosts postRank
LEFT JOIN 
    TopContributors contributors ON postRank.PostId = contributors.UserId
LEFT JOIN 
    RecursivePostHierarchy hierarchy ON postRank.PostId = hierarchy.PostId
WHERE 
    postRank.VoteRank <= 10
ORDER BY 
    postRank.UpVotes DESC;
