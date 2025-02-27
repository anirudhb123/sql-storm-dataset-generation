WITH TagOccurrences AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        TagName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        p.Body
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        TagOccurrences t ON t.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
    WHERE
        p.CreationDate >= NOW() - INTERVAL '30 days' -- Posts created in the last 30 days
    GROUP BY 
        p.Id, u.DisplayName
),
VoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Tags,
    rp.Body,
    COALESCE(vc.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vc.DownVotes, 0) AS TotalDownVotes,
    TO_CHAR(rp.CreationDate, 'YYYY-MM-DD HH24:MI:SS') AS FormattedCreationDate,
    COUNT(DISTINCT CASE WHEN b.UserId IS NOT NULL THEN b.Id END) AS BadgeCount
FROM 
    RecentPosts rp
LEFT JOIN 
    VoteCounts vc ON rp.PostId = vc.PostId
LEFT JOIN 
    Badges b ON b.UserId = rp.OwnerDisplayName
GROUP BY 
    rp.PostId, rp.Title, rp.CreationDate, rp.OwnerDisplayName, rp.Body, vc.UpVotes, vc.DownVotes
ORDER BY 
    TotalUpVotes DESC,
    rp.CreationDate DESC
LIMIT 10;
