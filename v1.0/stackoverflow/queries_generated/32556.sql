WITH UserVoteStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalVotes,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        UserVoteStatistics
    WHERE 
        TotalVotes > 0
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pm.UserDisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.ParentId END) AS AnswerCount -- Only consider answers if the post is of type Answer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts pm ON p.OwnerUserId = pm.OwnerUserId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, pm.UserDisplayName
)
SELECT 
    pu.DisplayName AS TopUser,
    pd.Title AS PostTitle,
    pd.CreationDate,
    pd.Score AS PostScore,
    pd.CommentCount AS TotalComments,
    pd.AnswerCount AS TotalAnswers
FROM 
    TopUsers pu
JOIN 
    PostDetails pd ON pu.UserId = pd.OwnerDisplayName
WHERE 
    pu.VoteRank <= 10 -- Only top 10 users
    AND pd.CreationDate BETWEEN '2022-01-01' AND '2022-12-31'
ORDER BY 
    pu.VoteRank, pd.Score DESC;
