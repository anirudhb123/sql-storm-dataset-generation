WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id, u.DisplayName
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.UserDisplayName, ', ') AS Commenters
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalOutput AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostTypeId,
        rp.ViewCount,
        rp.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        pc.Commenters,
        ua.DisplayName AS TopVoter,
        ua.UpVotes,
        ua.DownVotes,
        ua.TotalVotes,
        ua.TotalBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    LEFT JOIN 
        (SELECT UserId, DisplayName, RANK() OVER (ORDER BY TotalVotes DESC) AS UserRank
         FROM UserActivity) ua ON ua.UserRank = 1
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CASE WHEN PostTypeId = 1 THEN 'Question' 
         WHEN PostTypeId = 2 THEN 'Answer' 
         ELSE 'Other' END AS PostType,
    ViewCount,
    Score,
    CommentCount,
    Commenters,
    TopVoter,
    UpVotes,
    DownVotes,
    TotalVotes,
    TotalBadges
FROM 
    FinalOutput
WHERE 
    (CommentCount > 0 OR Score > 10) -- Ensure we get popular or engaged posts
ORDER BY 
    Score DESC, 
    ViewCount DESC
LIMIT 100;

-- Ensures we get together comments, scores, user activity, while ranking posts in a rich details overview.
