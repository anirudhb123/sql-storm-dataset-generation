WITH PostAggregate AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_array ON TRUE
    LEFT JOIN 
        Tags t ON tag_array = t.TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.Body,
    pa.Score,
    pa.ViewCount,
    pa.CreationDate,
    pa.Tags,
    pa.TagList,
    ua.UserId,
    ua.DisplayName AS QuestionOwner,
    ua.QuestionCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    phs.PostHistoryTypes,
    phs.LastEditDate
FROM 
    PostAggregate pa
JOIN 
    Users ua ON pa.PostId = ua.Id
JOIN 
    PostHistorySummary phs ON pa.PostId = phs.PostId
ORDER BY 
    pa.Score DESC, 
    pa.ViewCount DESC;
