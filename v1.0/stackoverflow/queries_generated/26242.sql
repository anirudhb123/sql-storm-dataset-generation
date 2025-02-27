WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    WHERE 
        p.PostTypeId = 1 -- Filter for Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, a.AcceptedAnswerId
),

PostedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate AS UserCreationDate,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),

PostEngagement AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        pu.UserId,
        pu.DisplayName AS AuthorDisplayName,
        pu.Reputation AS AuthorReputation,
        pu.TotalPosts AS AuthorTotalPosts,
        pu.AcceptedAnswers AS AuthorAcceptedAnswers,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY rp.PostId), 0) AS UpVotes, -- VoteTypeId 2 for UpMod
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY rp.PostId), 0) AS DownVotes -- VoteTypeId 3 for DownMod
    FROM 
        RankedPosts rp
    JOIN 
        PostedUsers pu ON rp.OwnerUserId = pu.UserId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
)

SELECT 
    pe.PostId,
    pe.Title,
    pe.ViewCount,
    pe.AuthorDisplayName,
    pe.AuthorReputation,
    pe.AuthorTotalPosts,
    pe.AuthorAcceptedAnswers,
    pe.UpVotes,
    pe.DownVotes,
    RANK() OVER (ORDER BY pe.ViewCount DESC) AS ViewRank
FROM 
    PostEngagement pe
WHERE 
    pe.AuthorReputation > 1000 -- Filter for high reputation authors
ORDER BY 
    ViewRank, pe.AuthorReputation DESC
LIMIT 100;
