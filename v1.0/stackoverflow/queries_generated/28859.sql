WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
    GROUP BY 
        p.Id
), 
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        u.Id
), 
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        v.TotalVotes,
        v.UpVotes,
        v.DownVotes,
        t.TagCount,
        t.TagList
    FROM 
        Posts p
    LEFT JOIN 
        UserVoteStats v ON p.OwnerUserId = v.UserId
    LEFT JOIN 
        PostTagCounts t ON p.Id = t.PostId
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
    ORDER BY 
        p.Score DESC, v.TotalVotes DESC
    LIMIT 10
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.TotalVotes,
    pp.UpVotes,
    pp.DownVotes,
    pp.TagCount,
    pp.TagList
FROM 
    PopularPosts pp
JOIN 
    Users u ON pp.OwnerUserId = u.Id
WHERE 
    u.Reputation > 1000 -- Filtering for users with reputation greater than 1000
ORDER BY 
    pp.Score DESC, pp.TotalVotes DESC;
