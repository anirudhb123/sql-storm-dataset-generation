WITH RecursivePostGraph AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostGraph rpg ON p.ParentId = rpg.PostId
    WHERE 
        p.PostTypeId = 2  -- Get answers only
),

PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(v.UpVotes - v.DownVotes) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostVoteCounts v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    u.DisplayName,
    u.Reputation,
    COALESCE(pg.PostId, 0) AS QuestionPostId,
    COALESCE(pg.Title, 'No Questions') AS QuestionTitle,
    pg.CreationDate AS QuestionCreationDate,
    COUNT(DISTINCT ans.PostId) AS AnswerCount,
    SUM(COALESCE(vc.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(vc.DownVotes, 0)) AS TotalDownVotes,
    ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
FROM 
    Users u
LEFT JOIN 
    RecursivePostGraph pg ON u.Id = pg.OwnerUserId
LEFT JOIN 
    Posts ans ON pg.PostId = ans.ParentId AND ans.PostTypeId = 2  -- Answer matches
LEFT JOIN 
    PostVoteCounts vc ON ans.Id = vc.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, pg.PostId, pg.Title, pg.CreationDate
HAVING 
    COUNT(DISTINCT ans.PostId) > 0  -- At least one answer for filtering
ORDER BY 
    UserRank
LIMIT 50;
