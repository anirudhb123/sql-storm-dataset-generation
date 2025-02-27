WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
        AND p.CreationDate >= DATEADD(year, -2, GETDATE())  -- Last 2 years
),
TagsExtracted AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT 
            Id, 
            UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName 
         FROM 
            Posts) t ON rp.PostId = t.Id
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation 
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000  -- Users with reputation more than 1000
)
SELECT 
    te.PostId,
    te.Title,
    te.Body,
    te.TagsList,
    ur.DisplayName,
    ur.Reputation,
    te.CreationDate,
    ph.Comment AS CloseReason,
    ph.CreationDate AS CloseDate
FROM 
    TagsExtracted te
JOIN 
    UserReputation ur ON te.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistory ph ON te.PostId = ph.PostId AND ph.PostHistoryTypeId = 10  -- Post Closed
WHERE 
    te.Rank <= 3  -- Top 3 ranked posts per user
ORDER BY 
    te.CreationDate DESC;  -- Most recent posts first
