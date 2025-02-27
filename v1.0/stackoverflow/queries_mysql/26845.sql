
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        LENGTH(TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags))) - LENGTH(REPLACE(TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags)), '><', '')) + 1 AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE((SELECT COUNT(*)
                  FROM Votes v
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE((SELECT COUNT(*)
                  FROM Votes v
                  WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, u.Reputation
),
FilteredPosts AS (
    SELECT 
        *,
        (UpVotes - DownVotes) AS NetVotes,
        (Reputation / NULLIF(TagCount, 0)) AS ReputationPerTag
    FROM 
        RecentPosts
    WHERE 
        TagCount > 0
),
RankedPosts AS (
    SELECT 
        *,
        @rank := IF(@prevTagCount = NetVotes, @rank, @rank + 1) AS Rank,
        @prevTagCount := NetVotes
    FROM 
        FilteredPosts, (SELECT @rank := 0, @prevTagCount := NULL) AS r
    ORDER BY 
        NetVotes DESC, CreationDate DESC
)
SELECT 
    PostId,
    Title,
    Body,
    OwnerDisplayName,
    CreationDate,
    TagCount,
    UpVotes,
    DownVotes,
    NetVotes,
    Reputation,
    ReputationPerTag,
    Rank
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
