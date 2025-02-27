WITH RecursivePostCTE AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL -- Starting with top-level posts (questions)
    UNION ALL
    SELECT 
        p2.Id,
        p2.Title,
        p2.ViewCount,
        p2.CreationDate,
        p2.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON p2.ParentId = r.Id -- Join to get answers to questions
),
PostWithScores AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        r.ViewCount,
        -- Concatenating all Tags into a single string 
        STRING_AGG(DISTINCT TRIM(t.TagName), ', ') AS Tags,
        CASE 
            WHEN r.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON b.UserId = p.OwnerUserId
    LEFT JOIN 
        RecursivePostCTE r ON p.Id = r.Id
    LEFT JOIN 
        LATERAL (SELECT unnest(STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::text) AS TagId) AS un
        ON un.TagId IS NOT NULL
    LEFT JOIN 
        Tags t ON CAST(t.TagName AS varchar(35)) = un.TagId 
    GROUP BY 
        p.Id, r.ViewCount, r.AcceptedAnswerId
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY HasAcceptedAnswer ORDER BY UpVotes DESC, CommentCount DESC) AS Rank
    FROM 
        PostWithScores
)
SELECT 
    rp.Id,
    rp.Title,
    rp.ViewCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    rp.BadgeCount,
    rp.Tags,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS RankGroup
FROM 
    RankedPosts rp
WHERE 
    rp.ViewCount > 100 -- Filter for popular posts
    AND rp.BadgeCount >= 1 -- Only show posts from users with at least one badge
ORDER BY 
    Rank; -- Order by their rank
