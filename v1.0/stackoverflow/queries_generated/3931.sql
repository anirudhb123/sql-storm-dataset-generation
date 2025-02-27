WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        UpVotes,
        DownVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
    WHERE 
        Reputation > 1000
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS AuthorName,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Pending'
        END AS AnswerStatus
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.AuthorName,
        p.AnswerStatus,
        COALESCE(cm.CommentCount, 0) AS CommentCount,
        COALESCE(pl.LinkCount, 0) AS LinkCount,
        COALESCE(uh.UserId, 0) AS HasUpVoted,
        COALESCE(uh.UserId, 0) AS HasDownVoted
    FROM 
        RecentPosts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cm ON p.PostId = cm.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS LinkCount
        FROM 
            PostLinks
        GROUP BY 
            PostId
    ) pl ON p.PostId = pl.PostId
    LEFT JOIN (
        SELECT 
            v.PostId,
            v.UserId
        FROM 
            Votes v
        WHERE 
            v.VoteTypeId = 2
            AND v.UserId = 2 -- Assuming UserId 2 is the current user
    ) uh ON p.PostId = uh.PostId
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.Reputation,
    t.TotalPosts,
    p.Title,
    p.CreationDate,
    p.AnswerStatus,
    p.CommentCount,
    p.LinkCount,
    CASE 
        WHEN p.HasUpVoted IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS UpVoted,
    CASE 
        WHEN p.HasDownVoted IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS DownVoted
FROM 
    TopUsers t
JOIN 
    PostStatistics p ON t.UserId = p.OwnerUserId
ORDER BY 
    t.ReputationRank, p.CreationDate DESC
LIMIT 50;
