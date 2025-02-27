WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
RecentTags AS (
    SELECT 
        p.Id AS PostId,
        string_agg(DISTINCT t.TagName, ', ') AS UniqueTags
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rt.UniqueTags,
    us.QuestionsAsked,
    us.TotalUpVotes,
    us.TotalDownVotes,
    rp.ViewCount
FROM 
    RankedPosts rp
JOIN 
    RecentTags rt ON rp.PostId = rt.PostId
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStatistics us ON us.UserId = rp.OwnerUserId
WHERE 
    rp.RN = 1 -- Return only the most recent post by each user
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
