WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.PostTypeId,
        CAST(p.Title AS VARCHAR(300)) AS Path
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.ParentId,
        p2.PostTypeId,
        CAST(ph.Path || ' -> ' || p2.Title AS VARCHAR(300)) AS Path
    FROM 
        Posts p2
    INNER JOIN 
        PostHierarchy ph ON p2.ParentId = ph.Id
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        MAX(c.CreationDate) AS LastCommentDate
    FROM
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(pa.AnswerCount) AS AnswersGiven
    FROM
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Posts pa ON pa.ParentId = p.Id AND pa.PostTypeId = 2
    GROUP BY 
        u.Id
),
Combined AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        pa.CommentCount,
        pa.TotalBounty,
        pa.UpVotes,
        pa.DownVotes,
        ua.QuestionsAsked,
        ua.AnswersGiven,
        ph.Path AS PostHierarchy
    FROM 
        Users u
    JOIN 
        UserActivity ua ON u.Id = ua.UserId
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostActivity pa ON p.Id = pa.PostId
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.Id
)
SELECT 
    *,
    CASE
        WHEN UpVotes > DownVotes THEN 'Positive'
        WHEN UpVotes < DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment,
    ROW_NUMBER() OVER (PARTITION BY UserId ORDER BY TotalBounty DESC) AS UserBountyRank
FROM 
    Combined
WHERE 
    PostTypeId = 1
ORDER BY 
    QuestionAsked DESC, AnswersGiven DESC;
