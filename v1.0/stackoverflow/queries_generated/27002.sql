WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag_name ON TRUE
    JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        rp.*,
        COALESCE(b.Name, 'No Badge') AS BadgeName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = rp.OwnerUserId AND b.Date = (
            SELECT MAX(Date)
            FROM Badges
            WHERE UserId = rp.OwnerUserId
        )
    WHERE 
        rp.rn = 1 -- Get only the most recent post of each user
),
TopVotedPosts AS (
    SELECT 
        rp.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        RecentPosts rp
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    GROUP BY 
        rp.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.Tags,
    rp.CreationDate,
    rp.LastActivityDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.Score,
    COALESCE(tv.VoteCount, 0) AS TotalVotes,
    rp.BadgeName
FROM 
    RecentPosts rp
LEFT JOIN 
    TopVotedPosts tv ON tv.PostId = rp.PostId
ORDER BY 
    TotalVotes DESC, rp.Score DESC
LIMIT 10;
