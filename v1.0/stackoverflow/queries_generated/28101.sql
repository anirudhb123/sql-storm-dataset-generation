WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.OwnerUserId,
        ARRAY_LENGTH(STRING_TO_ARRAY(p.Tags, ','), 1) AS TagCount,
        p.Body
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId = 1 -- Only questions
        AND p.ViewCount > 10
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
        AND p.CreationDate >= NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(p.Id) > 5
),
PostStatistics AS (
    SELECT 
        p.PostId,
        p.Title,
        p.CreationDate,
        p.TagCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        FilteredPosts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.PostId = c.PostId
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId, p.Title, p.CreationDate, p.TagCount, u.DisplayName
),
RankedPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.TagCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    rp.Rank,
    u.TotalBadges
FROM 
    RankedPosts rp
JOIN 
    MostActiveUsers u ON rp.OwnerDisplayName = u.DisplayName
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Rank;
