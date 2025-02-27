WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
    UNION ALL
    SELECT 
        p.Id, 
        p.Title, 
        p.PostTypeId, 
        p.AcceptedAnswerId,
        p.ParentId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC)
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.PostId) AS TotalPostsVotedOn
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostScoreStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(ph.ViewCount, 0) AS ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts ph ON ph.Id = p.Id
    WHERE 
        p.PostTypeId = 1  -- Filtering questions only
    GROUP BY 
        p.Id, p.Title, p.Score, ph.ViewCount
),
AggregatedData AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        p.Title AS PostTitle,
        ps.Score AS PostScore,
        ps.CommentCount,
        ps.ViewCount,
        uvs.UpVotes,
        uvs.DownVotes,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS Rank
    FROM 
        Users u
    JOIN 
        UserVoteStats uvs ON u.Id = uvs.UserId
    JOIN 
        PostScoreStats ps ON ps.PostId IN (SELECT PostId FROM RecursivePostHierarchy)
    WHERE 
        u.Reputation > 1000  -- Interested in users with higher reputation
)

SELECT 
    a.DisplayName,
    a.Reputation,
    a.PostTitle,
    a.PostScore,
    a.CommentCount,
    a.ViewCount,
    a.UpVotes,
    a.DownVotes,
    CASE 
        WHEN a.UpVotes > a.DownVotes THEN 'Positive'
        WHEN a.UpVotes < a.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    AggregatedData a
WHERE 
    a.Rank <= 50
ORDER BY 
    a.PostScore DESC, a.ViewCount DESC;
