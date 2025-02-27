WITH RelevantPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.OwnerUserId,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_name ON TRUE
    JOIN 
        Tags t ON t.TagName = tag_name
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 1000 -- Consider users with high reputation
    GROUP BY 
        u.Id
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.LastActivityDate,
        ru.UserId AS OwnerId,
        ru.DisplayName AS OwnerName,
        ru.Reputation AS OwnerReputation,
        ru.BadgeCount,
        ru.QuestionCount,
        ru.UpVotes,
        ru.DownVotes,
        rp.ViewCount,
        rp.Tags,
        EXTRACT(EPOCH FROM (rp.LastActivityDate - rp.CreationDate)) AS TimeToResponse
    FROM 
        RelevantPosts rp
    JOIN 
        ActiveUsers ru ON ru.UserId = rp.OwnerUserId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.LastActivityDate,
    ps.OwnerName,
    ps.OwnerReputation,
    ps.BadgeCount,
    ps.QuestionCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.ViewCount,
    ps.Tags,
    ps.TimeToResponse,
    CASE
        WHEN ps.UpVotes > ps.DownVotes THEN 'Positive'
        WHEN ps.UpVotes < ps.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PostStatistics ps
ORDER BY 
    ps.TimeToResponse DESC, 
    ps.ViewCount DESC;
