WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        RANK() OVER (ORDER BY COUNT(DISTINCT v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
        AND p.CreationDate >= NOW() - INTERVAL '365 days' -- Posts from the last year
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList -- Aggregating tags for display
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        LATERAL (
            SELECT 
                TRIM(SUBSTRING(tag FROM 2 FOR LENGTH(tag) - 2)) AS TagName
            FROM 
                UNNEST(string_to_array(rp.Tags, '><')) AS tag
        ) t ON true
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.OwnerDisplayName
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.TotalComments,
    fp.TotalVotes,
    fp.TotalBadges,
    fp.VoteRank,
    fp.TagsList
FROM 
    FilteredPosts fp
WHERE 
    fp.VoteRank <= 10 -- Get top 10 posts by votes
ORDER BY 
    fp.VoteRank;
